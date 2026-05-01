import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "selectedId", "dropdown", "actions", "requestsLink", "availabilityLink"]
  static values = { list: Array }

  connect() {
    this._handleOutsideClick = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._handleOutsideClick)
  }

  onFocus() {
    this._renderDropdown(this.listValue)
  }

  onSearch() {
    const q = this.searchTarget.value.trim().toLowerCase()
    const matches = q
      ? this.listValue.filter(n => n.name.toLowerCase().includes(q))
      : this.listValue
    this._renderDropdown(matches)
    if (!q) this._clearSelection()
  }

  _renderDropdown(items) {
    const box = this.dropdownTarget
    box.innerHTML = ""

    if (!items.length) {
      box.classList.add("hidden")
      return
    }

    items.forEach(n => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "hover:bg-gray-50 px-4 py-2.5 text-gray-700 text-left text-sm transition-colors w-full"
      btn.textContent = n.name
      btn.addEventListener("click", () => this._select(n))
      box.appendChild(btn)
    })

    box.classList.remove("hidden")
  }

  _select(nutritionist) {
    this.searchTarget.value = nutritionist.name
    this.selectedIdTarget.value = nutritionist.id
    this.dropdownTarget.classList.add("hidden")
    this.requestsLinkTarget.href = `/nutritionists/${nutritionist.id}/requests`
    this.availabilityLinkTarget.href = `/nutritionists/${nutritionist.id}/availability`
    this.actionsTarget.classList.remove("hidden")
  }

  _clearSelection() {
    this.selectedIdTarget.value = ""
    this.actionsTarget.classList.add("hidden")
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }
}
