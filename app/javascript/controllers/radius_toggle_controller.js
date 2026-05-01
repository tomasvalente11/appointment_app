import { Controller } from "@hotwired/stimulus"

// Shows/hides the radius dropdown based on whether the location field is filled.
export default class extends Controller {
  static targets = ["location", "radius"]

  connect() {
    this.update()
  }

  update() {
    this.radiusTarget.classList.toggle("hidden", !this.locationTarget.value.trim())
  }
}
