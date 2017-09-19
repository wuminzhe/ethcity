require 'eth'
module EthHelper
  using PatternMatch

  # nil or rawtx
  def generate_raw_transaction(priv, value, data, gas_limit, gas_price, to = nil)
    key = Eth::Key.from_private_key_hex priv
    transaction_count = get_transaction_count(key.address)
    return nil unless transaction_count >= 0

    args = {
        from: key.address,
        value: 0,
        data: '0x0',
        nonce: transaction_count,
        gas_limit: gas_limit,
        gas_price: gas_price
    }
    args[:value] = (value * 10**18).to_i if value
    args[:data] = data if data
    args[:to] = to if to
    tx = Eth::Tx.new(args)
    tx.sign key
    tx.hex
  end

  # nil or address
  def generate_address(priv, address_contract_address, gas_limit, gas_price)
    data = '0x' + Ethereum::Function.calc_id('makeWallet()')
    to = address_contract_address

    rawtx = generate_raw_transaction(priv, nil, data, gas_limit, gas_price, to)
    return nil unless rawtx

    txhash = send_raw_transaction(rawtx)
    return nil unless txhash

    status = transaction_getstatus(txhash)
    return nil unless status == '0'

    wait_for_miner(txhash)
    txlistinternal = account_txlistinternal(txhash)
    return nil unless txlistinternal.length > 0

    txlistinternal.first['contractAddress']
  end

  def account_txlistinternal(txhash)
    ret = Etherscan::Account.txlistinternal_txhash(txhash)
    match(ret) do
      with(_[:error, message]) { [] }
      with(_[:ok, result]) { result }
    end
  end

  # -1: error
  def get_transaction_count(address)
    ret = Etherscan::Proxy.eth_get_transaction_count(address, 'latest')
    match(ret) do
      with(_[:error, message]) { -1 }
      with(_[:ok, result]) { result.to_i(16) }
    end
  end

  # nil or txhash
  def send_raw_transaction(rawtx)
    ret = Etherscan::Proxy.eth_send_raw_transaction(rawtx)
    match(ret) do
      with(_[:error, message]) { nil }
      with(_[:ok, result]) { result }
    end
  end

  # '0': pass, '1': error
  def transaction_getstatus(txhash)
    ret = Etherscan::Transaction.getstatus(txhash)
    match(ret) do
      with(_[:error, message]) { '1' }
      with(_[:ok, result]) { result['isError'] }
    end
  end

  def get_transaction_by_hash(txhash)
    ret = Etherscan::Proxy.eth_get_transaction_by_hash(txhash)
    match(ret) do
      with(_[:error, message]) { nil }
      with(_[:ok, result]) { result }
    end
  end

  def block_number
    ret = Etherscan::Proxy.eth_block_number
    match(ret) do
      with(_[:error, message]) { nil }
      with(_[:ok, result]) { result }
    end
  end

  def get_block_by_number(block_number)
    ret = Etherscan::Proxy.eth_get_block_by_number(block_number, 'true')
    match(ret) do
      with(_[:error, message]) { nil }
      with(_[:ok, result]) { result }
    end
  end


  def wait_for_miner(txhash, timeout: 300.seconds, step: 5.seconds)
    start_time = Time.now
    loop do
      raise Timeout::Error if ((Time.now - start_time) > timeout)
      return true if mined?(txhash)
      sleep step
    end
  end

  def mined?(txhash)
    ret = Etherscan::Proxy.eth_get_transaction_by_hash(txhash)
    match(ret) do
      with(_[:error, message]) { false }
      with(_[:ok, result]) { result['blockNumber'].present? }
    end
  end

  # tools
  def hex_wei_to_dec_eth(wei)
    hex_to_dec(wei)/10.0**18
  end

  def dec_eth_to_hex_wei(value)
    dec_wei = (value * 10**18).to_i
    dec_to_hex(dec_wei)
  end

  def dec_to_hex(value)
    '0x'+value.to_s(16)
  end

  def hex_to_dec(value)
    value.to_i(16)
  end

  def str_to_hex(s)
    '0x'+s.each_byte.map { |b| b.to_s(16) }.join
  end

  def padding(str)
    if str.starts_with?('0x')
      str = str[2 .. str.length-1]
    end
    str.rjust(64, '0')
  end

  def without_0x(address)
    address[2 .. address.length-1]
  end
end