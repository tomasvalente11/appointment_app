import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const params = new URLSearchParams(window.location.search)
    const tab = params.get("tab")
    if (tab) this._activate(tab)
  }

  show(event) {
    this._activate(event.currentTarget.dataset.tab)
  }

  _activate(selected) {
    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === selected
      tab.classList.toggle("border-[#3aaa93]", active)
      tab.classList.toggle("text-[#3aaa93]", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-gray-500", !active)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.panel !== selected)
    })
  }
}
