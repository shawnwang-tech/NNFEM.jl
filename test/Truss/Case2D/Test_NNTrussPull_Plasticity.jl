using Revise
using Test 
using NNFEM
using PyCall
using PyPlot
using JLD2
using ADCME
using LinearAlgebra

include("nnutil.jl")


aedictae_scaled = matread("Data/trained_nn_fem.mat"); # using MAT
Wkey = "ae_scaledbackslashfully_connectedbackslashweightscolon0"
Wkey = "ae_scaledbackslashfully_connected_1backslashweightscolon0"
Wkey = "ae_scaledbackslashfully_connected_2backslashweightscolon0"
Wkey = "ae_scaledbackslashfully_connected_3backslashweightscolon0"
Wkey = "ae_scaledbackslashfully_connected_4backslashweightscolon0"
function nnae_scaled(net)
        W0 = aedictae_scaled["ae_scaledbackslashfully_connectedbackslashweightscolon0"]; b0 = aedictae_scaled["ae_scaledbackslashfully_connectedbackslashbiasescolon0"];
        isa(net, Array) ? (net = net * W0 .+ b0') : (net = net *W0 + b0)
        isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
        W1 = aedictae_scaled["ae_scaledbackslashfully_connected_1backslashweightscolon0"]; b1 = aedictae_scaled["ae_scaledbackslashfully_connected_1backslashbiasescolon0"];
        isa(net, Array) ? (net = net * W1 .+ b1') : (net = net *W1 + b1)
        isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
        W2 = aedictae_scaled["ae_scaledbackslashfully_connected_2backslashweightscolon0"]; b2 = aedictae_scaled["ae_scaledbackslashfully_connected_2backslashbiasescolon0"];
        isa(net, Array) ? (net = net * W2 .+ b2') : (net = net *W2 + b2)
        isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
        W3 = aedictae_scaled["ae_scaledbackslashfully_connected_3backslashweightscolon0"]; b3 = aedictae_scaled["ae_scaledbackslashfully_connected_3backslashbiasescolon0"];
        isa(net, Array) ? (net = net * W3 .+ b3') : (net = net *W3 + b3)
        isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
        W4 = aedictae_scaled["ae_scaledbackslashfully_connected_4backslashweightscolon0"]; b4 = aedictae_scaled["ae_scaledbackslashfully_connected_4backslashbiasescolon0"];
        isa(net, Array) ? (net = net * W4 .+ b4') : (net = net *W4 + b4)
        return net
end 


# aedictsingle = matread("Data/trained_nn_fem.mat"); # using MAT
# Wkey = "singlebackslashfully_connectedbackslashweightscolon0"
# Wkey = "singlebackslashfully_connected_1backslashweightscolon0"
# Wkey = "singlebackslashfully_connected_2backslashweightscolon0"
# Wkey = "singlebackslashfully_connected_3backslashweightscolon0"
# Wkey = "singlebackslashfully_connected_4backslashweightscolon0"
# function nnsingle(net)
#         W0 = aedictsingle["singlebackslashfully_connectedbackslashweightscolon0"]; b0 = aedictsingle["singlebackslashfully_connectedbackslashbiasescolon0"];
#         isa(net, Array) ? (net = net * W0 .+ b0') : (net = net *W0 + b0)
#         isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
#         W1 = aedictsingle["singlebackslashfully_connected_1backslashweightscolon0"]; b1 = aedictsingle["singlebackslashfully_connected_1backslashbiasescolon0"];
#         isa(net, Array) ? (net = net * W1 .+ b1') : (net = net *W1 + b1)
#         isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
#         W2 = aedictsingle["singlebackslashfully_connected_2backslashweightscolon0"]; b2 = aedictsingle["singlebackslashfully_connected_2backslashbiasescolon0"];
#         isa(net, Array) ? (net = net * W2 .+ b2') : (net = net *W2 + b2)
#         isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
#         W3 = aedictsingle["singlebackslashfully_connected_3backslashweightscolon0"]; b3 = aedictsingle["singlebackslashfully_connected_3backslashbiasescolon0"];
#         isa(net, Array) ? (net = net * W3 .+ b3') : (net = net *W3 + b3)
#         isa(net, Array) ? (net = tanh.(net)) : (net=tanh(net))
#         W4 = aedictsingle["singlebackslashfully_connected_4backslashweightscolon0"]; b4 = aedictsingle["singlebackslashfully_connected_4backslashbiasescolon0"];
#         isa(net, Array) ? (net = net * W4 .+ b4') : (net = net *W4 + b4)
#         return net
# end 

# testtype = "PlaneStressPlasticity"
testtype = "NeuralNetwork1D"

prop = Dict("name"=> testtype, "rho"=> 0.1, "E"=> 200, "B"=> 10.0,
            "sigmaY"=>0.300, "K"=>1/9*200, "A0"=> 1.0, "eta"=> 10.0, "nn"=>post_nn)

include("NNTrussPull_Domain.jl")

domain = Domain(nodes, elements, ndofs, EBC, g, FBC, fext)
state = zeros(domain.neqs)
∂u = zeros(domain.neqs)
globdat = GlobalData(state,zeros(domain.neqs), zeros(domain.neqs),∂u, domain.neqs, gt, ft)
assembleMassMatrix!(globdat, domain)
# need to update state in domain from globdat
updateStates!(domain, globdat)

for i = 1:NT
    @info i, "/" , NT
    solver = NewmarkSolver(Δt, globdat, domain, -1.0, 0.0, 1e-5, 1e-5, 100) # ok

#     if mod(i,10)==0
#     close("all")
#     scatter(nodes[:, 1], nodes[:,2], color="red")
#     u,v = domain.state[1:domain.nnodes], domain.state[domain.nnodes+1:end]
#     scatter(nodes[:, 1] + u, nodes[:,2] + v, color="blue")
#     savefig("Debug/$(i)_.png")
#     end
end

close("all")
figure()
scatter(nodes[:, 1], nodes[:,2], color="red")
u,v = domain.state[1:domain.nnodes], domain.state[domain.nnodes+1:end]
scatter(nodes[:, 1] + u, nodes[:,2] + v, color="blue")
ylim(-0.2,1.5)


figure()
X, Y = prepare_strain_stress_data1D(domain)
x = constant(X)
y = squeeze(nn(constant(X[:,1]), constant(X[:,2]), constant(X[:,3])))
sess = Session(); init(sess)
ADCME.load(sess, "Data/learned_nn.mat")
out = run(sess, y)
plot(X[:,1], out,"+", label="Learned NN")
plot(X[:,1], Y, ".", label="FEM NN")
legend()

