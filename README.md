# Resource Errors Formatter

Formatter to errors on save some record in database.

## Usage

The usage is simple, just pass the record to class and the errors will be formatted.

```ruby
def create
  @record = Contract.new(create_contract_params)

  if @record.save
    render('v1/defaults/show')
  else
    resource_errors = ResourceErrors.new(@record)
    render(
      json: { error: resource_errors.formatted_errors[:error].first }, status: :unprocessable_entity
    )
  end
end
```

## Output

The output of error will be:

```json
{
    "error": {
        "model": "Contract::PaymentHistoric",
        "model_human": "Histórico de Pagamento do Contrato",
        "field": "contract_payment_historic[due_date]",
        "attribute": "due_date",
        "attribute_human": "Data de vencimento",
        "id": null,
        "message": "não pode ser maior que a data de vencimento do contrato",
        "full_message": "Histórico de Pagamento do Contrato: Data de vencimento não pode ser maior que a data de vencimento do contrato"
    }
}
```
