import numpy as np
import matplotlib.pyplot as plt
import time
import random

# ── Load data ────────────────────────────────────────────────────────────────
with open("mnist_train.csv", 'r') as f:
    train_list = f.readlines()

with open("mnist_test.csv", 'r') as f:
    test_list = f.readlines()

print(f"Training samples : {len(train_list)}")
print(f"Test samples     : {len(test_list)}")


# ── Neural Network ───────────────────────────────────────────────────────────
class DNN:
    def __init__(self, sizes, epochs, lr=0.001, batch_size=32):
        self.sizes      = sizes
        self.epochs     = epochs
        self.lr         = lr
        self.batch_size = batch_size

        # Adam params
        self.beta1 = 0.9
        self.beta2 = 0.999
        self.eps   = 1e-8
        self.t     = 0

        i, h1, h2, o = sizes

        # He initialisation (correct for ReLU)
        self.params = {
            'W1': np.random.randn(h1, i)  * np.sqrt(2. / i),
            'b1': np.zeros((h1, 1)),
            'W2': np.random.randn(h2, h1) * np.sqrt(2. / h1),
            'b2': np.zeros((h2, 1)),
            'W3': np.random.randn(o,  h2) * np.sqrt(2. / h2),
            'b3': np.zeros((o,  1)),
        }

        self.m = {k: np.zeros_like(v) for k, v in self.params.items()}
        self.v = {k: np.zeros_like(v) for k, v in self.params.items()}

    # ── Activations ─────────────────────────────────────────────────────
    def relu(self, x):
        return np.maximum(0, x)

    def relu_deriv(self, x):
        return (x > 0).astype(float)

    def softmax(self, x):
        x   = x - np.max(x, axis=0, keepdims=True)
        exp = np.exp(x)
        return exp / np.sum(exp, axis=0, keepdims=True)

    # ── Forward ─────────────────────────────────────────────────────────
    def forward(self, X):
        p = self.params

        self.Z1 = p['W1'] @ X + p['b1']
        self.A1 = self.relu(self.Z1)

        self.Z2 = p['W2'] @ self.A1 + p['b2']
        self.A2 = self.relu(self.Z2)

        self.Z3 = p['W3'] @ self.A2 + p['b3']
        self.A3 = self.softmax(self.Z3)

        return self.A3

    # ── Backward ────────────────────────────────────────────────────────
    def backward(self, X, Y):
        p = self.params
        m = X.shape[1]

        dZ3 = self.A3 - Y
        dW3 = (dZ3 @ self.A2.T) / m
        db3 = np.sum(dZ3, axis=1, keepdims=True) / m

        dA2 = p['W3'].T @ dZ3
        dZ2 = dA2 * self.relu_deriv(self.Z2)
        dW2 = (dZ2 @ self.A1.T) / m
        db2 = np.sum(dZ2, axis=1, keepdims=True) / m

        dA1 = p['W2'].T @ dZ2
        dZ1 = dA1 * self.relu_deriv(self.Z1)
        dW1 = (dZ1 @ X.T) / m
        db1 = np.sum(dZ1, axis=1, keepdims=True) / m

        return {
            'W1': dW1, 'b1': db1,
            'W2': dW2, 'b2': db2,
            'W3': dW3, 'b3': db3,
        }

    # ── Adam update ─────────────────────────────────────────────────────
    def update(self, grads):
        self.t += 1
        lr_t = self.lr * np.sqrt(1 - self.beta2**self.t) / (1 - self.beta1**self.t)

        for k in self.params:
            self.m[k] = self.beta1 * self.m[k] + (1 - self.beta1) * grads[k]
            self.v[k] = self.beta2 * self.v[k] + (1 - self.beta2) * (grads[k]**2)
            self.params[k] -= lr_t * self.m[k] / (np.sqrt(self.v[k]) + self.eps)

    # ── Accuracy ────────────────────────────────────────────────────────
    def accuracy(self, data):
        correct = 0
        for row in data:
            vals   = row.split(',')
            x      = np.asarray(vals[1:], dtype=float) / 255.0
            x      = x.reshape(-1, 1)
            y_true = int(vals[0])
            y_pred = np.argmax(self.forward(x))
            if y_pred == y_true:
                correct += 1
        return correct / len(data)

    # ── Save weights ─────────────────────────────────────────────────────
    def save_weights(self, path="mnist_weights.npz"):
        np.savez(path, **self.params)
        print(f"\nWeights saved  → {path}")
        print(f"  Keys        : {list(self.params.keys())}")
        print(f"  Architecture: {self.sizes}")

    # ── Load weights (skip retraining) ───────────────────────────────────
    def load_weights(self, path="mnist_weights.npz"):
        data = np.load(path)
        for k in self.params:
            self.params[k] = data[k]
        print(f"Weights loaded ← {path}")

    # ── Training ────────────────────────────────────────────────────────
    def train(self, train_list, test_list):
        accs  = []
        start = time.time()

        for epoch in range(self.epochs):
            random.shuffle(train_list)

            for i in range(0, len(train_list), self.batch_size):
                batch = train_list[i:i + self.batch_size]
                X, Y  = [], []

                for row in batch:
                    vals = row.split(',')
                    x    = np.asarray(vals[1:], dtype=float) / 255.0
                    X.append(x)
                    y    = np.zeros(self.sizes[-1])
                    y[int(vals[0])] = 1.0
                    Y.append(y)

                X = np.array(X).T          # (784, batch_size)
                Y = np.array(Y).T          # (10,  batch_size)

                self.forward(X)
                grads = self.backward(X, Y)
                self.update(grads)

            acc = self.accuracy(test_list)
            accs.append(acc * 100)
            print(f"Epoch {epoch+1:2d}/{self.epochs} | "
                  f"Accuracy: {acc*100:.2f}% | "
                  f"Time: {time.time()-start:.1f}s")

        # ── Save weights after training ──────────────────────────────────
        self.save_weights("mnist_weights.npz")

        # ── Plot ─────────────────────────────────────────────────────────
        plt.figure(figsize=(8, 4))
        plt.plot(range(1, self.epochs + 1), accs, marker='o', color='steelblue')
        plt.xlabel("Epoch")
        plt.ylabel("Test Accuracy (%)")
        plt.title("MNIST DNN — Test Accuracy")
        plt.grid(True)
        plt.tight_layout()
        plt.savefig("accuracy_curve.png", dpi=120)
        plt.show()
        print("Accuracy curve saved → accuracy_curve.png")

        return accs


# ── Run ──────────────────────────────────────────────────────────────────────
dnn = DNN(
    sizes=[784, 128, 64, 10],
    epochs=20,                  # 20 is enough — Adam converges by ~epoch 15
    lr=0.001,
    batch_size=32,
)

dnn.train(train_list, test_list)

# ── To reload weights later without retraining ───────────────────────────────
# dnn2 = DNN(sizes=[784, 128, 64, 10], epochs=0, lr=0.001)
# dnn2.load_weights("mnist_weights.npz")
# print(f"Reloaded accuracy: {dnn2.accuracy(test_list)*100:.2f}%")