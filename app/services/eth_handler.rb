class EthHandler < BaseHandler

  attr_accessor :client

  def initialize
    super
    Etherscanio.logger = Logger.new(STDOUT)
    Etherscanio.logger.level = Logger::DEBUG
    @client = Etherscanio::Api.new(config[:etherscan_api_key], config[:chain])
  end

  # 获取交易所的地址上币
  def getbalance
    client.account_balance(config[:exchange_address], 'latest')
  end

  def getnewaddress(account, passphase)
    passed, txhash = generate_address

    if passed
      wait_for_miner(txhash)
      txlistinternal = client.account_txlistinternal_txhash(txhash)
      txlistinternal.length > 0 && txlistinternal.first['contractAddress']
    end

    return nil
  end

  def sendtoaddress(address, amount)

  end

  def status
    client.account_txlistinternal_txhash('0x8a4bfe54d737aea43b0778caaf26f8378016041530d8586b9242f853cacba464')
    # client.transaction_getstatus("0x0731da22aa72f1852dafb0089a55b5b8e1b5ece247fb440e5505a8dfb955b671")
  end

  private

  def generate_raw_transaction(key, data, to = nil)
    transaction_count = client.eth_getTransactionCount(key.address, 'latest')
    nonce = transaction_count.to_i(16)
    args = {
        from: key.address,
        value: 0,
        data: data,
        nonce: nonce,
        gas_limit: config[:gas_limit],
        gas_price: config[:gas_price]
    }
    args[:to] = to if to
    tx = Eth::Tx.new(args)
    tx.sign key
    tx.hex
  end

  def generate_address
    key = Eth::Key.new priv: config[:exchange_address_priv]
    data = '0x' + Ethereum::Function.calc_id('makeWallet()')
    to = config[:address_contract_address]

    rawtx = generate_raw_transaction(key, data, to)
    txhash = client.eth_sendRawTransaction(rawtx)

    status = client.transaction_getstatus(txhash)
    [status['isError'] == '0', txhash]
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
    client.eth_getTransactionByHash(txhash)['blockNumber'].present?
  end

end