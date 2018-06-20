require_dependency "policy_manager/application_controller"

module PolicyManager
  class CategoriesController < ApplicationController

    before_action :allow_admins 

    # GET /categories
    def index
      @categories = PolicyManager::Config.rules
    end

    # GET /categories/1
    def show
      @category = PolicyManager::Config.rules.find{|o| o.name == params[:id]}
      @terms = @category.terms.page(params[:page]).per(12)
    end

    private
  end
end
