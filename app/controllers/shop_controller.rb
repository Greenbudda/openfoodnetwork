class ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def products
    # Can we make this query less slow?
    #
    if @products = products_for_shop
      render status: 200,
        json: ActiveModel::ArraySerializer.new(@products, each_serializer: Api::ProductSerializer,
        current_order_cycle: current_order_cycle, current_distributor: current_distributor).to_json
    else
      render json: "", status: 404
    end
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        render partial: "json/order_cycle"
      else
        render status: 404, json: ""
      end
    else
      render partial: "json/order_cycle"
    end
  end

  private

  def products_for_shop
    current_order_cycle.andand
    .valid_products_distributed_by(current_distributor).andand
    .order(taxon_order).andand
    .select { |p| !p.deleted? && p.has_stock_for_distribution?(current_order_cycle, current_distributor) }
  end

  def taxon_order
    if current_distributor.preferred_shopfront_taxon_order.present?
      current_distributor
      .preferred_shopfront_taxon_order
      .split(",").map { |id| "primary_taxon_id=#{id} DESC" }
      .join(",") + ", name ASC"
    else
      "name ASC"
    end
  end
end
