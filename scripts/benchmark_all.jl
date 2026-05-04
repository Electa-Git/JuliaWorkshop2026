include("run_step0_baseline.jl") #dry run because @time includes compilation
include("run_step0_baseline.jl")
display(include("run_step1_function.jl"))
display(include("run_step2_no_globals.jl"))
display(include("run_step3_concretearrays.jl"))
display(include("run_step4_fix_Tnom_global.jl"))
display(include("run_step5_preallocate_arrays.jl"))
display(include("run_step6_microoptimizations.jl"))