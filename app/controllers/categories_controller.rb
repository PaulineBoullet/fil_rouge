class CategoriesController < ApplicationController
  def create
    category = Category.new(category_params.merge(position: Category.maximum(:position).to_i + 1))
    if category.save
      redirect_to ai_settings_path(anchor: "categories"), notice: "Catégorie ajoutée."
    else
      redirect_to ai_settings_path(anchor: "categories"), alert: "La catégorie doit avoir un nom."
    end
  end

  def update
    category = Category.find(params[:id])
    if category.update(category_params)
      redirect_to ai_settings_path(anchor: "categories"), notice: "Catégorie enregistrée."
    else
      redirect_to ai_settings_path(anchor: "categories"), alert: "La catégorie doit avoir un nom."
    end
  end

  def destroy
    Category.find(params[:id]).destroy
    redirect_to ai_settings_path(anchor: "categories"), notice: "Catégorie supprimée.", status: :see_other
  end

  private

  def category_params
    params.expect(category: [:name, :description])
  end
end
