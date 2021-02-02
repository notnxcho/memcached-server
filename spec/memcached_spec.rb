require_relative '../memcached.rb'

RSpec.describe Memcached do
	describe '#set_data' do
		let(:data_block) do
			{
				key: 'example_set_data',
				flags: 0,
				expiration_date: 40,
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
				expiration_date: 40,
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
end