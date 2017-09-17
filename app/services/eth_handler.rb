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
  rescue => e
    puts "Error: #{e}"
    puts e.backtrace[0, 20].join("\n")
  end

  def getnewaddress(account, passphase)
    key = ::Eth::Key.new
    key.private_hex
    key.public_hex
    puts key.address



    encrypted_key_info = Eth::Key.encrypt key, passphase
      # contract = Ethereum::Contract.create(file: Rails.root.join('config', 'contracts', 'sweeper.sol').to_s, address: config[:address_contract_address])
      # puts contract
  rescue Exception => e
    puts "Error: #{e}"
    puts e.backtrace[0, 20].join("\n")
  end

  def sendtoaddress(address, amount)

  end

  def generate_address
    key = Eth::Key.new priv: config[:exchange_address_priv]
    data = '0x' + Ethereum::Function.calc_id('makeWallet()')
    to = config[:address_contract_address]

    rawtx = generate_raw_transaction(key, data, to)
    txhash = client.eth_sendRawTransaction(rawtx)['result']

    client.transaction_getstatus(txhash)
  rescue Exception => e
    puts "Error: #{e}"
    puts e.backtrace[0, 20].join("\n")
  end

  def status
    client.transaction_getstatus("0x0731da22aa72f1852dafb0089a55b5b8e1b5ece247fb440e5505a8dfb955b671")
  end


  private

  def generate_raw_transaction(key, data, to = nil)
    transaction_count = client.eth_getTransactionCount(key.address, 'latest')
    nonce = transaction_count['result'].to_i(16)
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

  # def wait_for_miner(timeout: 300.seconds, step: 5.seconds)
  #   start_time = Time.now
  #   loop do
  #     raise Timeout::Error if ((Time.now - start_time) > timeout)
  #     return true if self.mined?
  #     sleep step
  #   end
  # end

end