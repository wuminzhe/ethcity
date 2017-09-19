class EthHandler < BaseHandler
  include EthHelper
  using PatternMatch

  def initialize
    super
    Etherscan.logger = Logger.new(STDOUT)
    Etherscan.logger.level = Logger::DEBUG
    Etherscan.api_key = config[:etherscan_api_key]
    Etherscan.chain = config[:chain]
  end

  # 获取交易所的地址上币
  def getbalance
    key = Eth::Key.from_private_key_hex config[:exchange_address_priv]
    ret = Etherscan::Account.balance(key.address, 'latest')
    match(ret) do
      with(_[:error, e]) { nil }
      with(_[:ok, result]) { result }
    end
  end

  def getnewaddress(account, passphase)
    generate_address(config[:exchange_address_priv],
                     config[:address_contract_address],
                     config[:gas_limit],
                     config[:gas_price])
  end

  def sendtoaddress(address, amount)
    rawtx = generate_raw_transaction(config[:exchange_address_priv],
                             amount,
                             nil,
                             config[:gas_limit],
                             config[:gas_price],
                             address)
    return nil unless rawtx

    send_raw_transaction(rawtx)
  end

  def gettransaction(txid)
    tx = get_transaction_by_hash(txid)
    return nil unless tx

    number = block_number
    return nil unless number

    current_block_number = hex_to_dec(number) # 当前的高度
    transaction_block_number = hex_to_dec(tx['blockNumber']) # 收到的就是已经上链的，不需要考虑blockNumber没有的情况

    tx['confirmations'] = current_block_number - transaction_block_number

    block = get_block_by_number(tx['blockNumber'])
    tx['timereceived'] = hex_to_dec(block['timestamp']) if block
    tx['details'] = [
      {
        'account' => 'payment',
        'category' => 'receive',
        'amount' => hex_wei_to_dec_eth(tx['value']),
        'address' => tx['to']
      }
    ]
    tx
  end


end