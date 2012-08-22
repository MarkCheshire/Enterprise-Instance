class AccountsController < ApplicationController
  def new
    @account = Account.new
  end
  
  def show
    @account
  end
  
  def create
    @account = Account.new(params[:account])
    render 'show'
  end
  
end
