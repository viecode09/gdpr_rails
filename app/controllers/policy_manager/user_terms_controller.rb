require_dependency "policy_manager/application_controller"

module PolicyManager
  class UserTermsController < ApplicationController

    skip_before_action :user_authenticated?, only: [:show, :accept, :reject, :blocking_terms]
    before_action :set_user_term, only: [:accept, :reject, :show, :edit, :update, :destroy]

    # GET /user_terms/1
    def show
      @user_term = current_user.present? ? current_user.handle_policy_for(@term) : UserTerm.new(term: @term, user: nil, state: cookies["policy_rule_#{@term.rule.name}"])
    end

    # GET /pending
    def pending
      @pending_policies = current_user.pending_policies
      respond_to do |format|
        format.html{ }
        format.json{ render json: @pending_policies }
      end
    end

    # GET /blocking_terms
    def blocking_terms
      respond_to do |format|
        format.html{ }
        format.json{ render json: PolicyManager::Config.rules
                                                       .select{|p| p.blocking }
                                                       .map(&:name) 
        }
      end
    end

    def accept_multiples
      rules = current_user.pending_policies.map{|o| "policy_rule_#{o.name}"}
      resource_params = params.require(:user).permit(rules)
      current_user.update_attributes(resource_params)
      @pending_policies = current_user.pending_policies
      
      respond_to do |format|
        format.html{ }
        format.json{ render json: @pending_policies }
      end
    end

    def accept
      
      handle_term_accept

      respond_to do |format|
        format.html{ 
          if @user_term.errors.any?
            redirect_to "/" , notice: "hey there are some errors! #{@user_term.errors.full_messages.join()}"
          else
            redirect_to "/"
          end
        }
        format.js
        format.json{
          render json: {
            status: @user_term ? @user_term.state : cookies["policy_rule_#{@term.rule.name}"]
          }
        }
      end
    end

    def reject
      handle_term_reject

      respond_to do |format|
        format.html{ 
          if @user_term.errors.any?
            redirect_to "/" , notice: "hey there are some errors! #{@user_term.errors.full_messages.join()}"
          else
            redirect_to "/"
          end
        }
        format.js
        format.json{
          if @user_term.present? && @user_term.errors.any?
            render json: { url: "/" , notice: "hey there are some errors! #{@user_term.errors.full_messages.join()}" }
          else
            render json: {
              state: @user_term ? @user_term.state : cookies["policy_rule_#{@term.rule.name}"]
            }
          end
        }
      end
    end

=begin
    # GET /user_terms/new
    def new
      @user_term = UserTerm.new
    end

    # POST /user_terms
    def create
      @user_term = UserTerm.new(user_term_params)

      if @user_term.save
        redirect_to @user_term, notice: 'User term was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /user_terms/1
    def update
      if @user_term.update(user_term_params)
        redirect_to @user_term, notice: 'User term was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /user_terms/1
    def destroy
      @user_term.destroy
      redirect_to user_terms_url, notice: 'User term was successfully destroyed.'
    end
=end

    private

      def handle_term_accept
        if current_user
          @user_term = current_user.handle_policy_for(@term)
          if @user_term.accept!
            @term.rule.on_accept.call(self) if @term.rule.on_accept.is_a?(Proc)
          end
        end

        cookies["policy_rule_#{@term.rule.name}"] = {
          :value => "accepted",
          :expires => 1.year.from_now
        }
      end

      def handle_term_reject
        if current_user
          @user_term = current_user.handle_policy_for(@term)
          if @user_term.reject!
            @term.rule.on_reject.call(self) if @term.rule.on_reject.is_a?(Proc)
          end
        end

        cookies.delete("policy_rule_#{@term.rule.name}")
      end

      # Use callbacks to share common setup or constraints between actions.
      def set_user_term
        @category = PolicyManager::Config.rules.find{|o| o.name == params[:id]}
        @term = @category.terms.last
      end

      # Only allow a trusted parameter "white list" through.
      def user_term_params
        params.fetch(:user_term, {})
      end
  end
end
