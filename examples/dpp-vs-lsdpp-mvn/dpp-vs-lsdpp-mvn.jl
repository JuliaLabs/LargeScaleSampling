# LSSampling
include("../../src/lssampling.jl")

# Sample size and dataset size
n = 200
N = 4000

# Generate synthetic data
file_paths = ["data1.txt", "data2.txt", "data3.txt", "data4.txt"]
generate_data(file_paths; N=N, feature_size=50);

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
    lsdpp = LSDPP(file_paths; chunksize=500, max=N)
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
savefig("dpp-probs-vs-lsdpp-probs-mvn.png")

# DPP theoretical inclusion probabilities vs LSDPP inclusion frequencies when
# sampling n points from a set of size N, with each point of size M
iterations = 20_000_000 # Use 20_000_000
lsdpp_freqs = relative_frequencies(lsdpp, n, iterations)
scatter(dpp_probs, lsdpp_freqs, color="red", alpha=0.5)
plot!(dpp_probs, dpp_probs, color="blue", alpha=0.5)
plot!(xlabel="DPP inclusion probabilities")
plot!(ylabel="LSDPP inclusion frequencies")
plot!(legend=false, dpi=300)
savefig("dpp-probs-vs-lsdpp-freqs-mvn.png")

# DPP theoretical inclusion probabilities vs LSDPP inclusion frequencies of 2 
# random points, when sampling n points from a set of size N, with each point of size M
set = rand(1:N, 2)
iterations = 1_000_000
lsdpp_set_freqs = relative_frequencies(lsdpp, set, n, iterations)
dpp_set_freqs = det(marginal_kernel(dpp)[set, set])
@printf("DPP inclusion probability for dataset %s is %f \n", 
         string(set), dpp_set_freqs)
@printf("LSDPP inclusion probability for dataset %s is %f \n",
         string(set), lsdpp_set_freqs)

