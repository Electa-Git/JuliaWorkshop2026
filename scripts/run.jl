import CSV
import YAML
import ArgParse
import MyModel
using MyModel.DCMotor
using MyModel.Load
using MyModel.PowerSource
import MyModel.Serialisation as SR

### * Parse arguments
function parse_cmd()
    s = ArgParse.ArgParseSettings()
    ArgParse.@add_arg_table s begin
        "--output", "-o"
        help = "output file"
        arg_type = String
        default = "result.csv"
        "system"
        help = "system config file"
        required = true
    end
    if isinteractive()
        Dict("output" => "result.csv", "system" => "system.yaml")
    else
        ArgParse.parse_args(s)
    end
end

function run(cfg)
    context = Dict{Symbol, Any}()
    motor = SR.deserialise(cfg[:motor], DCMotorWithWinding, context)
    load = SR.deserialise(cfg[:load], DampedLoad, context)
    powersource = SR.deserialise(cfg[:powersource], GenericPowerSource, context)
    f = MyModel.build_simulate_function(motor, load, powersource)
    (; tstart, tend, tstep) = (; cfg[:time]...)

    return (;
        time = tstart:tstep:tend,
        ((:omega, :i_a, :i_b) .=> MyModel.simulate(f, tstart, tend, tstep))...,
    )
end

function main(args)
    cfg = YAML.load_file(args["system"], dicttype = Dict{Symbol, Any})
    result = run(cfg)
    CSV.write(args["output"], result)
end

(abspath(PROGRAM_FILE) == @__FILE__() || isinteractive()) && main(parse_cmd())

# batch job
for io in [
        ("system.yaml", "result_independent.csv"),
        ("system_parallel.yaml", "result_parallel.csv"),
        ("system_series.yaml", "result_series.csv"),
        ("system_dip.yaml", "result_dip.csv"),
        ("system_parallel_dip.yaml", "result_parallel_dip.csv"),
    ]
    main(Dict("system" => joinpath("inputs", io[1]), "output" => joinpath("outputs", io[2])))
end
