require_relative '../memcached.rb'

RSpec.describe Memcached do
	describe '#set_data' do
		let(:data_block) do
			{
				key: 'example_set_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i
			}
		end

		subject { Memcached.set_data(data_block) }
		
		it 'stores the data' do
			expect(subject).to eq('STORED')
		end
	end

	describe '#add_data' do
		let(:data_block) do
			{
				key: 'example_add_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i
			}
		end

		subject { Memcached.add_data(data_block) }

		context 'when the key does not exist' do
			it 'stores the data' do
				expect(subject).to eq('STORED')
			end
		end

		context 'when the key exists' do
			before do
				Memcached.set_data(data_block)
			end
			
			it 'does not store the data' do
				expect(subject).to eq('NOT_STORED')
			end
		end	
	end

	describe '#append_data' do
		let(:data_block) do
			{
				key: 'example_append_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i
			}
		end

		subject { Memcached.append_data(data_block) }

		context 'when the key does not exists' do
			it 'does not append the new data' do
				expect(subject).to eq('NOT_STORED')
			end
		end

		context 'when the key exists' do
			before do
				Memcached.set_data(data_block)
			end

			it 'appends the new data' do
				expect(subject).to eq('STORED')
			end
		end
	end
	
	describe '#prepend_data' do
		let(:data_block) do
			{
				key: 'example_prepend_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i
			}
		end

		subject { Memcached.prepend_data(data_block) }

		context 'when the key does not exists' do
			it 'does not prepend the new data' do
				expect(subject).to eq('NOT_STORED')
			end
		end

		context 'when the key exists' do
			before do
				Memcached.set_data(data_block)
			end

			it 'prepends the new data' do
				expect(subject).to eq('STORED')
			end
		end
	end

	describe '#replace_data' do
		let(:data_block) do
			{
				key: 'example_replace_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i
			}
		end
		subject { Memcached.replace_data(data_block) }

		context 'when the key does not exist' do
			it 'does not replace any data' do
				expect(subject).to eq('NOT_STORED')
			end
		end

		context 'when the key exists' do
			before do
				Memcached.set_data(data_block)
			end
			it 'does replace the data' do
				expect(subject).to eq('STORED')
			end
		end

	end

	describe '#cas_data' do
		let(:data_block) do
			{
				key: 'example_cas_data',
				flags: 0,
				expiration_date: 4000,
				bytes: 100,
				data_block: 'Example data block',
				created_at: Time.now.to_i,
				cas_key: 111111,
				cas_key_given: cas_given_value 
			}
		end

		let(:cas_given_value) { 111111 }

		subject { Memcached.cas_data(data_block) }

		context 'the key does not exist' do
			it 'does not check or set anything' do
				expect(subject).to eq('NOT_FOUND')
			end
		end

		context 'the key does exist' do
			before do
				Memcached.set_data(data_block)
			end

			context 'the cas given does not match' do
				let(:cas_given_value) { 111112 } 
				it 'does not store the new data' do
					expect(subject).to eq('NOT_STORED')
				end
			end

			context 'the cas given does match' do
				it 'stores the new data' do
					expect(subject).to eq('STORED')
				end
			end
		end
	end

	describe '#get_data' do
		let(:keys) { ['key1', 'key2'] }

		subject { Memcached.get_data(keys) }

		context 'the keys do not exist' do
			it 'returns an empty array' do
				expect(subject).to eq([[], 'END'])
			end
		end

		context 'the key does exist' do
			let(:data_block_key1) do
				{
					key: 'key1',
					flags: 0,
					expiration_date: 4000,
					bytes: 100,
					data_block: 'Example data block key 1',
					created_at: Time.now.to_i
				}
			end
			
			before { Memcached.set_data(data_block_key1) }

			context 'there is just one valid key' do
				it 'returns an array with one block' do
					expect(subject).to eq([[data_block_key1], 'END'])
				end
			end

			context 'there are all valid keys' do
				let(:data_block_key2) do
					{
						key: 'key2',
						flags: 0,
						expiration_date: 4000,
						bytes: 100,
						data_block: 'Example data block key 1',
						created_at: Time.now.to_i
					}
				end

				before { Memcached.set_data(data_block_key2) }
				
				it 'returns an array of matching data blocks' do
					expect(subject).to eq([[data_block_key1, data_block_key2], 'END'])
				end
			end
		end
	end
end