using Test
import Base.redirect_stdout

function Base.redirect_stdout(f::Function, stream::IOBuffer)
    original_stdout = stdout
    rd, wr = redirect_stdout()
    try
        f()
    finally
        redirect_stdout(original_stdout)
        close(wr)
        write(stream, read(rd))
        close(rd)
    end
end

function stdout_to_string(f, args...)
    buf = IOBuffer()
    redirect_stdout(buf) do
        f(args...)
    end
    return String(take!(buf))
end

@testset "Q1" begin
    include("Q1.jl")
    @test stdout_to_string(q1, "log.txt") == ""

    @test stdout_to_string(q1, "test_Q1.txt") == """
    192.168.1.2 : 2020-10-19T13:32:30 - 2020-10-19T13:32:35
    10.20.30.1 : 2020-10-19T13:33:24 - 2020-10-19T13:33:29
    192.168.1.1 : 2020-10-19T13:32:34 - 2020-10-19T13:33:33
    """

end

@testset "Q2" begin
    include("Q2.jl")
    @test stdout_to_string(q2, "log.txt", 3) == ""
    @test stdout_to_string(q2, "test_Q2.txt", 1) ==
    """
    192.168.1.2 : 2020-10-19T13:32:30 - 2020-10-19T13:32:35
    10.20.30.1 : 2020-10-19T13:33:24 - 2020-10-19T13:33:29
    192.168.1.1 : 2020-10-19T13:32:34 - 2020-10-19T13:33:33
    10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q2, "test_Q2.txt", 2) ==
    """
    10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q2, "test_Q2.txt", 3) ==
    """
    10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """
end

@testset "Q3" begin
    include("Q3.jl")
    @test stdout_to_string(q3, "log.txt", 1, 100, 100) == ""

    @test stdout_to_string(q3, "test_Q2.txt", 1, 100, 100) ==
    """
    [down]       192.168.1.2 : 2020-10-19T13:32:30 - 2020-10-19T13:32:35
    [down]       10.20.30.1 : 2020-10-19T13:33:24 - 2020-10-19T13:33:29
    [down]       192.168.1.1 : 2020-10-19T13:32:34 - 2020-10-19T13:33:33
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down]       10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q3, "test_Q2.txt", 2, 100, 100) ==
    """
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down]       10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q3, "test_Q2.txt", 3, 100, 100) ==
    """
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q3, "test_Q3.txt", 3, 3, 49) ==
    """
    [overloaded] 10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded] 192.168.1.1 : 2020-10-20T13:00:20 - 2020-10-20T13:00:50
    [overloaded] 10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [overloaded] 192.168.1.1 : 2020-10-21T13:00:30 - 2020-11-19T13:34:20
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q3, "test_Q3.txt", 3, 3, 50) ==
    """
    [overloaded] 10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded] 10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q3, "test_Q3.txt", 3, 3, 100) ==
    """
    [overloaded] 10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q3, "test_Q3.txt", 3, 3, 1000) ==
    """
    [down]       10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]       192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]       10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

end

@testset "Q4" begin
    include("Q4.jl")
    @test stdout_to_string(q4, "log.txt", 1, 100, 100) == ""

    @test stdout_to_string(q4, "test_Q2.txt", 1, 100, 100) ==
    """
    [down]         192.168.1.2 : 2020-10-19T13:32:30 - 2020-10-19T13:32:35
    [down(subnet)] 192.168.1.0 : 2020-10-19T13:32:30 - 2020-10-19T13:32:35
    [down]         10.20.30.1 : 2020-10-19T13:33:24 - 2020-10-19T13:33:29
    [down]         192.168.1.1 : 2020-10-19T13:32:34 - 2020-10-19T13:33:33
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down(subnet)] 10.20.0.0 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down]         10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q4, "test_Q2.txt", 2, 100, 100) ==
    """
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:34:10 - 2020-11-19T13:34:20
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down(subnet)] 10.20.0.0 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [down]         10.20.30.2 : 2020-11-19T13:35:45 - 2020-12-19T13:31:25
    """

    @test stdout_to_string(q4, "test_Q2.txt", 3, 100, 100) ==
    """
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q4, "test_Q3.txt", 3, 3, 49) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded]   192.168.1.1 : 2020-10-20T13:00:20 - 2020-10-20T13:00:50
    [overloaded]   10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [overloaded]   192.168.1.1 : 2020-10-21T13:00:30 - 2020-11-19T13:34:20
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q4, "test_Q3.txt", 3, 3, 50) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded]   10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q4, "test_Q3.txt", 3, 3, 100) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q4, "test_Q3.txt", 3, 3, 1000) ==
    """
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    """

    @test stdout_to_string(q4, "test_Q4.txt", 3, 3, 50) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded]   10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [down]         10.20.30.2 : 2020-11-19T13:35:36 - 2020-11-19T13:35:39
    [down(subnet)] 10.20.0.0 : 2020-11-19T13:35:25 - 2020-11-19T13:35:39
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [overloaded]   10.20.30.1 : 2020-12-19T13:32:24 - 2020-12-19T14:35:35
    [down]         192.168.1.1 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down(subnet)] 192.168.1.0 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down]         192.168.1.2 : 2020-12-19T14:40:40 - 2020-12-19T14:41:30
    [down]         10.20.30.1 : 2020-12-19T14:35:25 - 2020-12-19T14:41:40
    [down(subnet)] 10.20.0.0 : 2020-12-19T14:35:25 - 2020-12-19T14:41:40
    [down]         10.20.30.2 : 2020-12-19T14:35:36 - 2020-12-19T14:41:50
    """

    @test stdout_to_string(q4, "test_Q4.txt", 3, 3, 49) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded]   192.168.1.1 : 2020-10-20T13:00:20 - 2020-10-20T13:00:50
    [overloaded]   10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:33:26
    [down]         10.20.30.1 : 2020-11-19T13:33:24 - 2020-11-19T13:33:27
    [overloaded]   192.168.1.1 : 2020-10-21T13:00:30 - 2020-11-19T13:34:20
    [down]         10.20.30.2 : 2020-11-19T13:35:36 - 2020-11-19T13:35:39
    [down(subnet)] 10.20.0.0 : 2020-11-19T13:35:25 - 2020-11-19T13:35:39
    [down]         192.168.1.1 : 2020-11-19T13:35:10 - 2020-11-19T13:35:40
    [down]         10.20.30.1 : 2020-11-19T13:35:25 - 2020-11-19T13:35:55
    [overloaded]   10.20.30.1 : 2020-12-19T13:32:24 - 2020-12-19T14:35:35
    [down]         192.168.1.1 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down(subnet)] 192.168.1.0 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down]         192.168.1.2 : 2020-12-19T14:40:40 - 2020-12-19T14:41:30
    [down]         10.20.30.1 : 2020-12-19T14:35:25 - 2020-12-19T14:41:40
    [down(subnet)] 10.20.0.0 : 2020-12-19T14:35:25 - 2020-12-19T14:41:40
    [down]         10.20.30.2 : 2020-12-19T14:35:36 - 2020-12-19T14:41:50
    """
    
    @test stdout_to_string(q4, "test_Q4.txt", 4, 3, 50) ==
    """
    [overloaded]   10.20.30.2 : 2020-10-19T13:32:25 - 2020-10-19T13:33:26
    [overloaded]   10.20.30.1 : 2020-10-20T13:00:35 - 2020-11-19T13:35:55
    [down]         192.168.1.1 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down(subnet)] 192.168.1.0 : 2020-12-19T14:35:10 - 2020-12-19T14:41:20
    [down]         192.168.1.2 : 2020-12-19T14:40:40 - 2020-12-19T14:41:30
    """
end