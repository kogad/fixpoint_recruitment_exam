include("util.jl")
include("Q3.jl")

const SubnetAddress = String

"""
    SubnetStatus(is_down, is_down_prev)

1つのサブネットの故障状態を表す．
"""
mutable struct SubnetStatus
    is_down::Bool
    is_down_prev::Bool

    SubnetStatus() = new(false, false)
end

"""
    prefix_length_to_mask(len)

プレフィックス長からサブネットマスクを作る．
サブネットマスクは，後の計算のためにStringではなくIntの配列で持つ．
"""
function prefix_length_to_mask(len)
    all_one = len ÷ 8
    rest = len % 8

    mask = repeat([255], all_one)
    if rest > 0
        push!(mask, parse(Int, "1"^rest * "0"^(8 - rest), base=2))
        zero_bits = repeat([0], 4 - all_one - 1)
        append!(mask, zero_bits)
    else
        zero_bits = repeat([0], 4 - all_one)
        append!(mask, zero_bits)
    end

    return mask
end

"""
    address_to_prefix(address, prefix_len)

サーバーのアドレスとプレフィックス長から，ネットワークプレフィックスを計算する．
ネットワークプレフィックスは，後の計算のためにStringではなくIntの配列で持つ．
"""
function address_to_prefix(address, prefix_len)
    mask = prefix_length_to_mask(prefix_len)
    address = split(address, ".")
    prefix = String[]
    for i in 1:length(mask)
        num = mask[i] & parse(Int, address[i])
        push!(prefix, string(num))
    end
    return join(prefix, ".")
end


"""
    is_down(prefix_to_servers, server_statuses, prefix)

サブネットの故障を判定する．
サブネットないの全サーバーが故障していたらサブネットの故障とみなす．
"""
function is_down(prefix_to_servers, server_statuses, prefix)
    servers = prefix_to_servers[prefix]
    all_down = true
    for server in servers
        all_down &= server_statuses[server].is_down
        all_down || break
    end

    return all_down
end

"""
    can_recover_from_down(prefix_to_servers, server_statuses, prefix)

サブネットの状態を故障状態から復活させられるかを返す．
サブネットないのサーバが1つでも生きていれば復活．
"""
function can_recover_from_down(prefix_to_servers, server_statuses, prefix)
    servers = prefix_to_servers[prefix]
    for server in servers
        if !server_statuses[server].is_down
            return true
        end
    end
    
    return false
end

"""
    trainsit!(subnet_statuses, prefix_to_servers, prefix, server_statuses, address)

サブネットの状態を遷移させる．
サブネットが落ちていたら故障状態にする．そうでなければ非故障状態にする．．
"""
function trainsit!(subnet_statuses, prefix_to_servers, prefix, server_statuses, address)
    subnet_statuses[prefix].is_down_prev = subnet_statuses[prefix].is_down
    subnet_statuses[prefix].is_down = is_down(prefix_to_servers, server_statuses, prefix)
end


"""
    did_transit_to_down(subnet_statuses::Dict{String, SubnetStatus}, prefix)

サブネットの状態が非故障から故障に遷移したかどうかを返す．
"""
function did_transit_to_down(subnet_statuses::Dict{String, SubnetStatus}, prefix)
    now = subnet_statuses[prefix].is_down
    prev = subnet_statuses[prefix].is_down
    return now && !prev
end

"""
    first_down_in_subnet(server_statuses, prefix_to_servers, prefix)

サブネット内で最初のサーバー故障かどうかを返す．
"""
function is_first_down_in_subnet(server_statuses, prefix_to_servers, prefix)
    num_down_server = 0
    servers = prefix_to_servers[prefix]
    for server in servers
        num_down_server += server_statuses[server].is_down
    end
    return num_down_server == 1
end

"""
    did_recoverd(subnet_statuses::Dict{SubnetAddress, SubnetStatus}, prefix)

サブネットの状態が故障状態から非故障状態に遷移したかどうかを返す．
"""
function did_recoverd(subnet_statuses::Dict{SubnetAddress, SubnetStatus}, prefix)
    now = subnet_statuses[prefix].is_down
    prev = subnet_statuses[prefix].is_down_prev
    return !now && prev
end


"""
    q4(filename, n, m, t)

設問4に答える関数．
サブネットに関する部分以外はq3()と同様．
1つのサブネットに属するサーバーが全て故障したら，サブネットの故障とみなす．
サブネットの故障期間は，そのサブネット内で最初に故障したサーバーの故障時刻から，サブネットないのいずれかのサーバーが復活した時刻までである．
1つのサーバーが故障するたびにサブネットの故障判定を行い，1つのサーバーが復活するたびにサブネットの復活判定を行う．
"""
function q4(filename, n, m, t)
    server_statuses = Dict{String, ServerStatus}()
    server_records = Dict{String, ServerRecord}()
    server_logs = read_log(filename)

    prefix_to_servers = Dict{SubnetAddress, Vector{String}}()
    subnet_statuses = Dict{SubnetAddress, SubnetStatus}()
    subnet_down_times = Dict{SubnetAddress, DateTime}()

    # 存在するサーバーとサブネットを先に知っておく
    for server_log in server_logs
        prefix = address_to_prefix(server_log.address, server_log.prefix)
        if !haskey(server_statuses, server_log.address)
            server_statuses[server_log.address] = ServerStatus()
            server_records[server_log.address] = ServerRecord()

            if !haskey(prefix_to_servers, prefix)
                prefix_to_servers[prefix] = []
                subnet_statuses[prefix] = SubnetStatus()
            end

            if !(server_log.address in prefix_to_servers[prefix])
                push!(prefix_to_servers[prefix], server_log.address)
            end
        end
    end

    for server_log in server_logs
        prefix = address_to_prefix(server_log.address, server_log.prefix)
        update_timeout!(server_records, server_log)
        record_response_time!(server_records, server_log)

        trainsit!(server_statuses, server_records, server_log, n, m, t)

        trainsit!(subnet_statuses, prefix_to_servers, prefix, server_statuses, server_log.address)

        if did_transit_to_down(server_statuses, server_log.address) && is_first_down_in_subnet(server_statuses, prefix_to_servers, prefix)
            subnet_down_times[prefix] = server_records[server_log.address].first_timeout
        end


        # サーバーが故障・過負荷から復帰していたら期間を出力
        if did_transit_to_overloaded(server_statuses, server_log.address)
            record_overloaded_time!(server_records, server_log.address, server_log)
        end

        if did_recoverd_from_down(server_statuses, server_log.address)
            print("[down]         ")
            print(server_log.address, " : ")
            println(server_records[server_log.address].first_timeout, " - ", server_log.time)
            clear_timeout_counter!(server_records, server_log.address)

            if did_recoverd(subnet_statuses, prefix)
                print("[down(subnet)] ")
                print(prefix, " : ")
                println(subnet_down_times[prefix], " - ", server_log.time)
            end

        elseif did_recoverd_from_overloaded(server_statuses, server_log.address)
            print("[overloaded]   ")
            print(server_log.address, " : ")
            println(server_records[server_log.address].first_overloaded, " - ", server_log.time)
        end

    end
end