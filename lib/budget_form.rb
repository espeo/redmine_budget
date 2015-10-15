class BudgetForm
  unloadable

  attr_reader :budget, :params, :error, :project_role_budgets, :income_wages, :cost_wages

  def initialize(budget, params = nil)
    @budget = budget
    @params = params

    unless params.present?
      @project_role_budgets = budget.project.project_role_budgets.joins(:role).merge(Role.sorted)
      @income_wages = budget.income_wages
      @cost_wages = budget.cost_wages
    end
  end

  def next_project_role_budget_uid
    if @next_project_role_budget_uid.nil?
      @next_project_role_budget_uid = Time.now.to_i
    else
      @next_project_role_budget_uid += 1
    end
  end

  def next_wage_uid
    if @next_wage_uid.nil?
      @next_wage_uid = Time.now.to_i
    else
      @next_wage_uid += 1
    end
  end

  def save
    ## ProjectRoleBudgets
    params['project_role_budgets'] = params['project_role_budgets'].values
      .select { |x| x['role_id'] && x['hours_count'].to_i > 0 }

    existing_role_budget_ids = params['project_role_budgets'].map { |x| x['id'] }

    @project_role_budgets = params['project_role_budgets'].map do |row_params|
      project_role_budget = budget.project.project_role_budgets.new do |x| 
        x.id = (row_params['id'] if row_params['id'].to_i > 0) || next_project_role_budget_uid
      end

      project_role_budget.attributes = row_params.slice(*%w(role_id hours_count))
      project_role_budget
    end

    ## Wages
    params['wages'] = params['wages'].values
      .select { |x| x['role_id'] && x['price_per_hour'].to_i > 0 }

    existing_wage_ids = params['wages'].map { |x| x['id'] }

    wages = params['wages'].map do |row_params|
      wage = budget.project.wages.new do |x| 
        x.id = (row_params['id'] if row_params['id'].to_i > 0) || next_wage_uid
      end

      wage.attributes = row_params.slice(*%w(role_id type price_per_hour start_date end_date))
      wage
    end

    @cost_wages = wages.select { |wage| wage.type == Wage::TYPES[:cost] }
    @income_wages = wages.select { |wage| wage.type == Wage::TYPES[:income] }

    begin
      Wage.transaction do
        ProjectRoleBudget.where(project_id: budget.project.id).delete_all
        project_role_budgets.each(&:save!)

        Wage.where(project_id: budget.project.id).delete_all
        wages.each(&:save!)

        budget.attributes = params.slice(*%w(warning_percent_threshold))
        budget.updated_at = Time.now
        budget.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      @error = e
      false
    end
  end
end
