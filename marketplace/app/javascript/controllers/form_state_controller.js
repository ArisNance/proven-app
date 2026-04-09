import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.handleSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("submit", this.handleSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.handleSubmit)
  }

  handleSubmit() {
    this.element.setAttribute("aria-busy", "true")

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.dataset.originalText = this.submitTarget.textContent
      this.submitTarget.textContent = this.submitTarget.dataset.loadingText || "Saving..."
    }
  }
}
