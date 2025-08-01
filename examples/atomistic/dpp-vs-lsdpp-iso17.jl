# LSSampling
include("../../src/lssampling.jl")

# Domain specific feature calculation
include("utils/atom-conf-features-extxyz.jl")

# Basis function to compute ACE descriptors (features)
basis = ACE(species           = [:C, :O, :H],
            body_order        = 4,
            polynomial_degree = 4,
            rcutoff           = 5.0,
            wL                = 1.0,
            csp               = 1.0,
            r0                = 1.0);

# Data
file_paths = ["data/iso17/my_iso17_train.extxyz"]

# Sample size and dataset size
n = 200
N = 6000

# Sampling by DPP
Random.seed!(42) # Fix seed to compare DPP and LSDPP: get same random chunks
@time begin
    ch = chunk_iterator(file_paths; chunksize=N)
    chunk, _ = take!(ch)
    features = create_features(chunk)
    K = pairwise(Euclidean(), features')
    dpp = EllEnsemble(K)
    rescale!(dpp, n)
    dpp_probs = Determinantal.inclusion_prob(dpp)
    dpp_indexes = Determinantal.sample(dpp, n)
end
chunk = nothing;
features = nothing;
GC.gc()

# Sampling by LSDPP
Random.seed!(42) # Fix seed to compare DPP and LSDPP: get same random chunks
@time begin
    lsdpp = LSDPP(file_paths; chunksize=1500, max=N)
    lsdpp_probs = inclusion_prob(lsdpp, n)
    lsdpp_indexes = sample(lsdpp, n)
end

# Tests and plots

# DPP vs. LSDPP inclusion probabilities when sampling 
# n points from a set of size N, with each point of size M
scatter(dpp_probs, lsdpp_probs, color="red", alpha=0.5)
plot!(dpp_probs, dpp_probs, color="blue", alpha=0.5)
plot!(xlabel="DPP inclusion probabilities")
plot!(ylabel="LSDPP inclusion probabilities")
plot!(legend=false, dpi=300)
savefig("dpp-probs-vs-lsdpp-probs-iso17.png")

# DPP theoretical inclusion probabilities vs LSDPP inclusion frequencies when
# sampling n points from a set of size N, with each point of size M
iterations = 20_000_000 # Use 20_000_000
lsdpp_freqs = relative_frequencies(lsdpp, n, iterations)
scatter(dpp_probs, lsdpp_freqs, color="red", alpha=0.5)
plot!(dpp_probs, dpp_probs, color="blue", alpha=0.5)
plot!(xlabel="DPP inclusion probabilities")
plot!(ylabel="LSDPP inclusion frequencies")
plot!(legend=false, dpi=300)
savefig("dpp-probs-vs-lsdpp-freqs-iso17.png")

# DPP theoretical inclusion probabilities vs LSDPP inclusion frequencies of 2 
# random points, when sampling n points from a set of size N, with each point of size M
set = rand(1:N, 2)
iterations = 10 # Use 10_000_000
lsdpp_set_freqs = relative_frequencies(lsdpp, set, n, iterations)
dpp_set_freqs = det(marginal_kernel(dpp)[set, set])
@printf("DPP inclusion probability for dataset %s is %f \n", 
         string(set), dpp_set_freqs)
@printf("LSDPP inclusion probability for dataset %s is %f \n",
         string(set), lsdpp_set_freqs)

