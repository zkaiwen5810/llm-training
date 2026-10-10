"""Check CPU PyTorch tensors, autograd, and a simple optimizer step."""

import torch

torch.manual_seed(42)
torch.set_num_threads(2)
assert torch.version.cuda is None, "Expected the CPU-only PyTorch build"
model = torch.nn.Linear(1, 1)
optimizer = torch.optim.SGD(model.parameters(), lr=0.1)
x = torch.linspace(-1, 1, 32).reshape(-1, 1)
y = 2 * x + 1
initial = torch.nn.functional.mse_loss(model(x), y).item()
for _ in range(50):
    optimizer.zero_grad()
    loss = torch.nn.functional.mse_loss(model(x), y)
    loss.backward()
    optimizer.step()
final = torch.nn.functional.mse_loss(model(x), y).item()
assert final < initial, (initial, final)
print(f"PyTorch {torch.__version__} | CPU | loss {initial:.4f} -> {final:.4f}")
