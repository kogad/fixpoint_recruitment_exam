using Statistics

include("util.jl")
include("Q2.jl")

"""
    ServerStatus(is_overloaded, is_down, is_overloaded_prev, is_down_prev)

サーバーが，現在と前回のping応答時に故障または過負荷状態であるかを表す．
"""
mutable struct ServerStatus
    is_down::Bool
    is_down_prev::Bool

    is_overloaded::Bool
    is_overloaded_prev::Bool

    ServerStatus() = new(false, false, false, false)
end


"""
    ServerRecord(timeout_counter, response_times,, response_times, first_timeout, first_overloaded)

サーバーの過去の応答に関する記録をまとめる構造体．
`timeout_counter` は連続タイムアウト数．
`response_times` は過去の応答時間
`first_timeout` は連続タイムアウトの1回目の時刻
`first_overloaded` は過負荷状態になったときの時刻
"""
mutable struct ServerRecord
    timeout_counter::Int
    response_times::Vector{Int}
    first_timeout::DateTime
    first_overloaded::DateTime
    
    ServerRecord() = new(0, [], now(), now())
end


"""
    went_down(server_records, address, n)

サーバーがダウンしたかどうかを判定する．
連続タイムアウト数がN回以上ならダウンと判定．
"""

function went_down(server_records, address, n)
    return server_records[address].timeout_counter >= n
end


"""
    went_overloaded(server_records, address, m, t)

サーバーが過負荷状態になったかを判定する．
現在までの応答回数がm回未満なら過負荷ではないと判断．
過去m回の平均応答時間がt以上かつ連続タイムアウト中ではない場合に過負荷状態であると判断．
そうでないなら過負荷状態ではないと判断．

"""
function went_overloaded(server_records, address, m, t)
    if length(server_records[address].response_times) < m
        return false
    end

    @views recent_response_times = server_records[address].response_times[end-m+1:end]
    avg_response_time = mean(recent_response_times)

    return server_records[address].timeout_counter == 0 && avg_response_time > t
end


"""
    can_recover_from_down(server_log)

故障から復帰できるかを判定する．
ping応答がタイムアウトしていなければ復帰可能．
"""
can_recover_from_down(server_log) = server_log.response_time != timeout


"""
    can_recover_from_overloaded(server_records, address, m, t)

過負荷状態から復帰できるかを判定する．
過去m回の平均応答時間がt以下なら過負荷で亡くなったとし，復帰と判断
"""
function can_recover_from_overloaded(server_records, address, m, t)
    @views recent_response_times = server_records[address].response_times[end-m+1:end]
    avg_response_time = mean(recent_response_times)

    return avg_response_time <= t
end

"""
    went_down_from_overloaded(server_records, address, n)

過負荷状態中に故障したかどうかを判定する．
過負荷状態でない場合と同様に，N回連続タイムアウトで故障と判定する．
"""
went_down_from_overloaded(server_records, address, n) = went_down(server_records, address, n)


"""
    trainsit!(server_statuses, server_records, server_log, n, m, t)

サーバーの過負荷・故障状態を遷移させる．
サーバーの状態とその遷移先は以下の通り．
    1. 非故障・低負荷
        1. 故障・低負荷 
        2. 非故障・過負荷
    2. 故障・低負荷
        1. 非故障・低負荷
    3. 非故障・過負荷
        1. 非故障・低負荷
        2. 故障・低負荷

また，1つ前の状態を記録しておく．
"""
function trainsit!(server_statuses, server_records, server_log, n, m, t)
    address = server_log.address

    server_statuses[address].is_down_prev = server_statuses[address].is_down
    server_statuses[address].is_overloaded_prev = server_statuses[address].is_overloaded

    is_down_now = server_statuses[address].is_down
    is_overloaded_now = server_statuses[address].is_overloaded


    if !is_down_now && !is_overloaded_now
        if went_down(server_records, address, n)
            server_statuses[address].is_down = true

        elseif went_overloaded(server_records, address, m, t)
            server_statuses[address].is_overloaded = true
        end

    elseif is_down_now && !is_overloaded_now
        if can_recover_from_down(server_log)
            server_statuses[address].is_down = false
        end

    elseif !is_down_now && is_overloaded_now
        if can_recover_from_overloaded(server_records, address, m, t)
            server_statuses[address].is_overloaded = false

        elseif went_down_from_overloaded(server_records, address, n)
            server_statuses[address].is_overloaded = false
            server_statuses[address].is_down = true
        end

    else
        # not considered 
    end
end


"""
    did_recoverd_from_down(server_statuses, address)

サーバーが故障から復帰したかどうかを判定する．
現在の状態と前回の応答時の状態をみて判定する．
"""
function did_recoverd_from_down(server_statuses, address)
    now = server_statuses[address].is_down
    prev = server_statuses[address].is_down_prev
    return !now && prev
end

"""
    did_recoverd_from_overloaded(server_statuses, address)

サーバーが故障から復帰したかどうかを判定する．
現在の状態と前回の応答時の状態をみて判定する．
"""
function did_recoverd_from_overloaded(server_statuses, address)
    now = server_statuses[address].is_overloaded
    prev = server_statuses[address].is_overloaded_prev
    return !now && prev
end


"""
    did_transit_to_overloaded(server_statuses, address)

過負荷状態に遷移したかどうかを返す．
現在の状態と前回の応答時の状態をみて判定する．
"""
function did_transit_to_overloaded(server_statuses, address)
    now = server_statuses[address].is_overloaded
    prev = server_statuses[address].is_overloaded_prev
    return now && !prev
end

"""
    did_transit_to_overloaded(server_statuses, address)

故障状態に遷移したかどうかを返す．
現在の状態と前回の応答時の状態をみて判定する．
"""
function did_transit_to_down(server_statuses, address)
    now = server_statuses[address].is_down
    prev = server_statuses[address].is_down_prev
    return now && !prev
end


"""
    record_overloaded_time!(server_records, address, server_log)

過負荷状態に遷移した時に，その時刻を記録する．
"""
function record_overloaded_time!(server_records, address, server_log)
    server_records[address].first_overloaded = server_log.time
end



"""
    update_timeout!(server_records, server_log)

連続タイムアウト数とタイムアウト時刻の更新．
タイムアウトしていればタイムアウト回数を＋1．
それが初回タイムアウトなら時刻を記録．
タイムアウトしていたらタイムアウト回数を0に．
"""
function update_timeout!(server_records, server_log)
    if is_timeout(server_log)
        if server_records[server_log.address].timeout_counter == 0
            server_records[server_log.address].first_timeout = server_log.time
        end
        server_records[server_log.address].timeout_counter += 1
    else
        server_records[server_log.address].timeout_counter = 0
    end
end

"""
    clear_timeout_counter!(server_records, address)

連続タイムアウト数を0にする．
"""
function clear_timeout_counter!(server_records, address)
    server_records[address].timeout_counter = 0
end



"""
    record_response_time!(server_records, server_log)

pingの応答時間を記録する．
"""
function record_response_time!(server_records, server_log)
    if !is_timeout(server_log)
        push!(server_records[server_log.address].response_times, server_log.response_time)
    end
end


"""
    q3(filename, n, m, t)

設問3に回答する関数．
監視ログを1行ずつ確認し，
    - 連続タイムアウトのカウント・応答時間を記録
    - サーバーの故障・負荷状態の遷移
    - 故障・過負荷の期間を出力
を行う.
過負荷の期間は，応答時間の平均がtを超えた時点から，t以下になるまで．
過負荷かどうかの判定ではタイムアウトを無視する．
"""
function q3(filename, n, m, t)
    server_statuses = Dict{String, ServerStatus}()
    server_records = Dict{String, ServerRecord}()
    server_logs = read_log(filename)
    for server_log in server_logs
        if !haskey(server_statuses, server_log.address)
            server_statuses[server_log.address] = ServerStatus()
            server_records[server_log.address] = ServerRecord()
        end

        update_timeout!(server_records, server_log)
        record_response_time!(server_records, server_log)

        trainsit!(server_statuses, server_records, server_log, n, m, t)

        if did_transit_to_overloaded(server_statuses, server_log.address)
            record_overloaded_time!(server_records, server_log.address, server_log)
        end

        if did_recoverd_from_down(server_statuses, server_log.address)
            print("[down]       ")
            print(server_log.address, " : ")
            println(server_records[server_log.address].first_timeout, " - ", server_log.time)
            clear_timeout_counter!(server_records, server_log.address)

        elseif did_recoverd_from_overloaded(server_statuses, server_log.address)
            print("[overloaded] ")
            print(server_log.address, " : ")
            println(server_records[server_log.address].first_overloaded, " - ", server_log.time)
        end

    end
end