require 'rails_helper'

RSpec.describe QueryObject do
  let(:account) { create(:account) }
  let(:products) { create_list(:product, 3, account: account) }
  before { products }
  describe 'anonymous class' do
    let(:products_query_class) {
      Class.new(QueryObject) do
        def all
          @relation = paginate
          @relation = by_ids if params[:ids]
          @relation = since_id if params[:since_id]
          @relation = created_at_min if params[:created_at_min]
          @relation = created_at_max if params[:created_at_max]
          @relation = id_max if params[:id_max]
          @relation = id_min if params[:id_min]
          return @relation
        end
      end
    }

    let(:query) { products_query_class.new params, account.products }
    describe '#all' do
      let(:params) do
        {
          ids: [products[0].id, products[1].id],
          id_min: products[1].id
        }
      end

      it "filters query with params" do
        expect(query.all.count).to eq(1)
      end
    end

    context 'using ids' do
      let(:params) { { ids: [products[0].id, products[1].id] } }

      it "filters query" do
        expect(query.all.count).to eq(2)
      end
    end


    context 'using limit' do
      let(:params) { { limit: 2, page: 1} }

      it "filters query" do
        expect(query.all.count).to eq(2)
      end
    end

    context 'with page' do
      context "1" do
        let(:params) { { limit: 2, page: 1} }
        it "returns first page" do
          expect(query.all.count).to eq(2)
        end
      end

      context "1" do
        let(:params) { { limit: 2, page: 2} }
        it "returns first page" do
          expect(query.all.count).to eq(1)
        end
      end
    end

    context "using since_id" do
      let(:params) { { since_id: products[1].id } }
      it "returns list of products" do
        expect(query.all.count).to eq(1)
      end
    end


    context "using attribute_min" do
      it "returns list of products" do
        # TODO: Improve this test
        # there are 3 default products
        Timecop.freeze(Time.current + 1.day)
        product1 = create(:product, account: account)
        Timecop.return
        Timecop.freeze(Time.current + 2.day)
        product2 = create(:product, account: account)
        Timecop.return
        q = products_query_class.new({ created_at_min: product1.created_at }, account.products)
        expect(q.all.count).to eq(2)
      end

      it "returns list of products" do
        # TODO: Improve this test
        # there are 3 default products
        # create products before the the current date
        Timecop.freeze(Time.current - 1.day)
        product1 = create(:product, account: account)
        Timecop.return
        Timecop.freeze(Time.current - 2.day)
        product2 = create(:product, account: account)
        Timecop.return
        q = products_query_class.new({ created_at_max: product1.created_at + 1 }, account.products)
        expect(q.all.count).to eq(2)
      end
    end
  end
end