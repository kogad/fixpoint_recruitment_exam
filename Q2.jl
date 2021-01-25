include("util.jl")

"""
    TimeoutLog(first_timeout, n_timeout)

サーバーの連続したタイムアウトを表す構造体．
1度だけのタイムアウトも，連続1回のタイムアウトとして扱う．
`first_timeout`は最初にタイムアウトした時刻．
`n_timeout`は連続したタイムアウトの数．
"""
mutable struct TimeoutLog
    first_timeout::DateTime 
    n_timeout::Int
end

"""
    increment_timeout!(timeout_counter, server_log)

連続タイムアウトの回数を1回増やす関数．
`timeout_counter`はサーバーのアドレス → `TimeoutLog`のdictionary.
連続1回目のタイムアウト時は，そのサーバーで連続1回のタイムアウトが発生したとして`timeout_counter`に追加．
"""
function increment_timeout!(timeout_counter, server_log)
    if haskey(timeout_counter, server_log.address)
        timeout_counter[server_log.address].n_timeout += 1
    else
        timeout_counter[server_log.address] = TimeoutLog(server_log.time, 1)
    end
end


"""
    is_timeout(server_log)

サーバーがタイムアウトしているかどうかを真偽値で返す．
"""
is_timeout(server_log) = server_log.response_time == timeout

"""
    is_down(server_log, timeout_counter, n)

サーバーが故障しているかどうかを真偽値返す．
`timeout_counter`を参照して，`server_log`のサーバーが `n`回以上連続でタイムアウトしていたら，そのサーバーは故障しているとみなす．
"""
is_down(server_log, timeout_counter, n) = timeout_counter[server_log.address].n_timeout >= n

"""
    is_recoverd(server_log, timeout_counter, n)

サーバーが故障から復帰したかどうかを真偽値で返す．
ping応答でサーバーがタイムアウトしておらず，その応答以前でサーバーが故障していたら復帰したとみなす．
"""
function is_recoverd(server_log, timeout_counter, n) 
    if haskey(timeout_counter, server_log.address)
        return is_down(server_log, timeout_counter, n) && !is_timeout(server_log)
    else
        return false
    end
end

"""
    clear_timeout_counter!(timeout_counter, server_log)

サーバーの連続タイムアウトの記録をクリアする．
"""
clear_timeout_counter!(timeout_counter, server_log) = delete!(timeout_counter, server_log.address)

"""
    downtime(server_log, timeout_counter)

`timeout_counter`から初回タイムアウト時刻を読んで返す．
"""
down_time(server_log, timeout_counter::Dict) = timeout_counter[server_log.address].first_timeout


"""
    q2(filename, n)

設問2に回答する関数．
監視ログを1行ずつ確認し，
    - サーバーが`n`回連続タイムアウトしていれば故障とみなす
    - 正常に応答しているが直近のログで故障していたら復帰したとみなし故障期間を表示する
という処理を行う．
"""
function q2(filename, n)
    timeout_counter = Dict{String, TimeoutLog}()
    server_logs = read_log(filename)
    for server_log in server_logs
        if is_recoverd(server_log, timeout_counter, n)
            print(server_log.address, " : ")
            println(down_time(server_log, timeout_counter), " - ", server_log.time)
            clear_timeout_counter!(timeout_counter, server_log)
        elseif is_timeout(server_log)
            increment_timeout!(timeout_counter, server_log)
        else
            clear_timeout_counter!(timeout_counter, server_log)
        end
    end
end