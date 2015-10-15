get 'budget' => 'budget#show', as: :budget
get 'projects/:project_id/budget' => 'budget#show', as: :project_budget
get 'budget/raport' => 'budget#raport', as: :budget_raport
get 'projects/:project_id/budget/raport' => 'budget#raport', as: :project_budget_raport
get 'projects/:project_id/budget/settings' => 'budget#edit', as: :edit_project_budget
post 'projects/:project_id/budget/settings' => 'budget#update'

resources :projects do
  resources :budget_entries, path: "budget/entries", except: [:index, :show]
  resources :budget_entries_categories, path: "budget/categories", except: [:show]
end

get 'projects/:project_id/budget/worktime' => 'worktime#show', as: :project_worktime
put 'projects/:project_id/budget/worktime' => 'worktime#update', as: :update_project_worktime
post 'projects/:project_id/budget/worktime/holidays' => 'worktime#create_holiday', as: :project_holidays
delete 'projects/:project_id/budget/worktime/holidays/:id' => 'worktime#destroy_holiday', as: :project_holiday
