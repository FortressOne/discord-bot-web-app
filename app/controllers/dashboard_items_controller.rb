class DashboardItemsController < ApplicationController
  def index
    @dashboard_items = DashboardItems.all
  end
end
