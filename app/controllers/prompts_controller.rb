class PromptsController < ApplicationController
  before_action :set_prompt, only: %i[edit update destroy]

  def index
    @prompts = Prompt.order(:name)
  end

  def new
    @prompt = Prompt.new
  end

  def create
    @prompt = Prompt.new(prompt_params)
    if @prompt.save
      redirect_to prompts_path, notice: "Prompt ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prompt.update(prompt_params)
      redirect_to prompts_path, notice: "Prompt modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prompt.destroy
    redirect_to prompts_path, notice: "Prompt supprimé.", status: :see_other
  end

  private

  def set_prompt
    @prompt = Prompt.find(params[:id])
  end

  def prompt_params
    params.expect(prompt: [:name, :content])
  end
end
