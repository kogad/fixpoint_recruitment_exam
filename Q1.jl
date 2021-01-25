include("util.jl")

"""
    is_down(server_log)

ping応答が故障しているかどうかの真偽値を返す関数．
設問1ではタイムアウト＝故障なので，タイムアウトしているかどうかを返す．
`server_log`は`ServerPingLog`で，ping応答を表す．
"""
is_down(server_log) = server_log.response_time == timeout

"""
    is_recoverd(server_log, down_logs)

ping応答確認の結果，サーバーが故障から復帰したかどうかを返す関数．
故障していたサーバから正常なping応答が帰ってきた場合，故障から復帰したものとみなす．
ping応答がタイムアウトしていない場合に，`server_log`としてping応答を渡す．
`down_logs`は，サーバーが故障したときのping応答の配列．
"""
function is_recoverd(server_log, down_logs)
    for down_log in down_logs
        if down_log.address == server_log.address
            return true
        end
    end
    return false
end

"""
    down_time(server_log, down_logs)

サーバーが故障した時刻を返す関数．
サーバーが故障から復帰したときのping応答を渡すと，そのサーバの故障を確認したときのping応答を検索（線形探索）し，故障確認時刻を返す．
"""
function down_time(server_log, down_logs)
    for down_log in down_logs
        if down_log.address == server_log.address
            return down_log.time
        end
    end
end

"""
    q1(filename)

設問1に解答する関数．
監視ログを1行ずつ確認し，
    - サーバーがタイムアウトしていれば故障とみなす
    - 正常に応答しているが直近のログで故障していたら復帰したとみなし故障期間を表示する
という処理を行う．
"""
function q1(filename)
    down_logs = ServerPingLog[]
    server_logs = read_log(filename)
    for server_log in server_logs
        if is_down(server_log)
            push!(down_logs, server_log)
            continue
        end

        if is_recoverd(server_log, down_logs)
            print(server_log.address, " : ")
            println(down_time(server_log, down_logs), " - ", server_log.time)
        end
    end
end

