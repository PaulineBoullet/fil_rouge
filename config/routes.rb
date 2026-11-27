Rails.application.routes.draw do
  devise_for :users

  # Consultation : dashboard → domaine tiers → fil → mail
  root "pages#dashboard"
  get "recherche" => "search#index", as: :search
  get "domaines-tiers/:id" => "companies#show", as: :company_view
  post "domaines-tiers/:id/synthese" => "companies#analyze_emails", as: :analyze_company

  resources :conversations, path: "fils", only: :show do
    member do
      patch :toggle_hidden
      post :analyze
    end
  end
  resources :emails, path: "mails", only: :show do
    member do
      get :attachment
      post :analyze
    end
  end

  # Paramètres
  scope "parametres" do
    resource :organization, path: "mon-domaine", only: %i[show update], controller: "settings" do
      post :reidentify, on: :member
    end
    resources :employees, path: "collaborateurs", only: %i[edit update]
    resources :companies, path: "domaines-tiers", except: :show do
      patch :validate, on: :member
    end
    resources :contacts, path: "correspondants", except: :show do
      member do
        patch :validate
        patch :block
        patch :unblock
      end
    end
    get "reglages-ia" => "ai_settings#show", as: :ai_settings
    resources :categories, only: %i[create update destroy]
    resources :statuses, only: %i[create update destroy] do
      patch :move, on: :member
    end
    resources :prompts, only: %i[create update destroy] do
      patch :assign, on: :member
    end
    resources :import_failures, path: "mails-en-erreur", only: :index
  end

  get "icone" => "brand_icons#show", as: :brand_icon

  get "up" => "rails/health#show", as: :rails_health_check
end
