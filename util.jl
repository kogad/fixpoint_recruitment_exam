using Dates

"""
    ServerPingLog(time, address, prefix, response_time)

ping応答の結果を格納する構造体．
"""
struct ServerPingLog
    time::DateTime
    address::String
    prefix::Int
    response_time::Int
end

const df = Dates.DateFormat("yyyymmddHHMMSS")
const timeout = -1

"""
    parse_log(log_str)

監視ログの1行を表す文字列から `ServerPingLog` を作って返す関数．
"""
function parse_log(log_str)
    time, prefixed_address, response_time_str = split(log_str, ",")
    address, prefix_str = split(prefixed_address, "/")


    local response_time
    if response_time_str == "-"
        response_time = timeout
    else
        response_time = parse(Int, string(response_time_str))
    end

    prefix = parse(Int, prefix_str)

    return ServerPingLog(DateTime(time, df), address, prefix, response_time)
end

"""
    read_log(filename)

監視ログファイル `filename` を読み込み，`ServerPingLog`の配列を返す．
"""
function read_log(filename)
    server_logs = ServerPingLog[]
    open(filename, "r") do f
        for line in readlines(f)
            push!(server_logs, parse_log(line))
        end
    end

    return server_logs
end