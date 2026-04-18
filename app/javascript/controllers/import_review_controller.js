import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rowCheckbox", "selectAll", "selectedCount"]

  connect() {
    this.updateCount()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.rowCheckboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateCount()
  }

  updateCount() {
    const count = this.rowCheckboxTargets.filter(cb => cb.checked).length
    this.selectedCountTarget.textContent = count

    if (this.hasSelectAllTarget) {
      const total = this.rowCheckboxTargets.length
      this.selectAllTarget.checked = count === total
      this.selectAllTarget.indeterminate = count > 0 && count < total
    }
  }
}
