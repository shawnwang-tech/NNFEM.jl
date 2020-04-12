using ADCME
using PyCall
using LinearAlgebra
using PyPlot
using Random
using NNFEM
Random.seed!(233)

function finit_continuum_strain(state)
    finit_continuum_strain_ = load_op_and_grad("./build/libFinitContinuumStrain","finit_continuum_strain")
    state = convert_to_tensor([state], [Float64]); state = state[1]
    finit_continuum_strain_(state)
end

domain = example_domain()
init_nnfem(domain)
state = rand(domain.nnodes*2)
# TODO: specify your input parameters
u = finit_continuum_strain(state)
sess = Session(); init(sess)
@show run(sess, u)

# uncomment it for testing gradients
# error() 


# TODO: change your test parameter to `m`
#       in the case of `multiple=true`, you also need to specify which component you are testings
# gradient check -- v
function scalar_function(m)
    return sum(finit_continuum_strain(m)^2)
end

# TODO: change `m_` and `v_` to appropriate values
m_ = constant(rand(domain.nnodes*2))
v_ = rand(domain.nnodes*2)
y_ = scalar_function(m_)
dy_ = gradients(y_, m_)
ms_ = Array{Any}(undef, 5)
ys_ = Array{Any}(undef, 5)
s_ = Array{Any}(undef, 5)
w_ = Array{Any}(undef, 5)
gs_ =  @. 1 / 10^(1:5)

for i = 1:5
    g_ = gs_[i]
    ms_[i] = m_ + g_*v_
    ys_[i] = scalar_function(ms_[i])
    s_[i] = ys_[i] - y_
    w_[i] = s_[i] - g_*sum(v_.*dy_)
end

sess = Session(); init(sess)
sval_ = run(sess, s_)
wval_ = run(sess, w_)
close("all")
loglog(gs_, abs.(sval_), "*-", label="finite difference")
loglog(gs_, abs.(wval_), "+-", label="automatic differentiation")
loglog(gs_, gs_.^2 * 0.5*abs(wval_[1])/gs_[1]^2, "--",label="\$\\mathcal{O}(\\gamma^2)\$")
loglog(gs_, gs_ * 0.5*abs(sval_[1])/gs_[1], "--",label="\$\\mathcal{O}(\\gamma)\$")

plt.gca().invert_xaxis()
legend()
xlabel("\$\\gamma\$")
ylabel("Error")
