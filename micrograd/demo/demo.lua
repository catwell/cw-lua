local MLP = (require "micrograd.nn").MLP
local Value = (require "micrograd.engine").Value

local dataset = {}
assert(loadfile("demo/dataset.lua", "t", dataset))()

local model = MLP(2, {16, 16, 1})
print(model)
print("number of parameters", #model:parameters())

local X, y = dataset.X, dataset.y

local function loss()
    local Xb, yb = X, y -- no batch

    local inputs = {}
    for i, xrow in ipairs(Xb) do
        inputs[i] = {Value(xrow[1]), Value(xrow[2])}
    end

    -- forward the model to get scores
    local scores = {}
    for i, input in ipairs(inputs) do
        scores[i] = model(input)
    end

    -- svm "max-margin" loss
    local losses = {}
    for i, yi in ipairs(yb) do
        local scorei = scores[i]
        losses[i] = (1 - scorei * yi):relu()
    end
    local data_loss = losses[1]
    for i = 2, #losses do
        data_loss = data_loss + losses[i]
    end
    data_loss = data_loss * (1.0 / #losses)

    -- L2 regularization
    local alpha = 1e-4
    local ps = model:parameters()
    local sum_p2 = ps[1] * ps[1]
    for i = 2, #ps do
        sum_p2 = sum_p2 + ps[i] * ps[i]
    end
    local reg_loss = alpha * sum_p2
    local total_loss = data_loss + reg_loss

    -- also get accuracy
    local accuracy = 0
    for i, yi in ipairs(yb) do
        local scorei = scores[i]
        if (yi > 0) == (scorei.data > 0) then
            accuracy = accuracy + 1
        end
    end

    return total_loss, accuracy / #yb
end

total_loss, acc = loss()
print(total_loss, acc)

for k = 0, 99 do
    -- forward
    local total_loss, acc = loss()

    -- backward
    model:zero_grad()
    total_loss:backward()

    -- update (sgd)
    local learning_rate = 1.0 - 0.9 * k / 100

    for _, p in ipairs(model:parameters()) do
        p.data = p.data - learning_rate * p.grad
    end

    print(string.format(
        "step %d loss %f, accuracy %d%%",
        k, total_loss.data, acc * 100
    ))
end
