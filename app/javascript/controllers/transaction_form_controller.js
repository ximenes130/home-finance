import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "kindRadio"]

  connect() {
    this.allOptions = Array.from(this.categoryTarget.options).map(option => ({
      value: option.value,
      text: option.text,
      kind: option.dataset.kind
    }))
    this.filterCategories()
  }

  filterCategories() {
    const selectedKind = this.selectedKind
    const currentValue = this.categoryTarget.value

    // Remove all options except the blank one
    while (this.categoryTarget.options.length > 0) {
      this.categoryTarget.remove(0)
    }

    // Re-add matching options
    this.allOptions.forEach(opt => {
      if (!opt.kind || opt.kind === selectedKind) {
        const option = new Option(opt.text, opt.value)
        option.dataset.kind = opt.kind || ""
        this.categoryTarget.add(option)
      }
    })

    // Restore selection if still valid, otherwise reset
    const validValues = Array.from(this.categoryTarget.options).map(o => o.value)
    if (validValues.includes(currentValue)) {
      this.categoryTarget.value = currentValue
    } else {
      this.categoryTarget.value = ""
    }
  }

  get selectedKind() {
    const checked = this.element.querySelector('input[name="transaction[kind]"]:checked')
    return checked ? checked.value : "expense"
  }
}
