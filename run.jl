if ARGS[1] == "1"
    include("Q1.jl")
    q1(ARGS[2])

elseif ARGS[1] == "2"
    include("Q2.jl")
    n = parse(Int, ARGS[3])
    q2(ARGS[2], n)

elseif ARGS[1] == "3"
    include("Q3.jl")
    n = parse(Int, ARGS[3])
    m = parse(Int, ARGS[4])
    t = parse(Int, ARGS[5])
    q3(ARGS[2], n, m, t)

elseif ARGS[1] == "4"
    include("Q4.jl")
    n = parse(Int, ARGS[3])
    m = parse(Int, ARGS[4])
    t = parse(Int, ARGS[5])
    q4(ARGS[2], n, m, t)
end