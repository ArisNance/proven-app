import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: Number }

  connect() {
    const timeout = this.hasTimeoutValue ? this.timeoutValue : 3000
    this.dismissTimer = window.setTimeout(() => this.dismiss(), timeout)
  }

  disconnect() {
    if (this.dismissTimer) {
      window.clearTimeout(this.dismissTimer)
    }
  }

  dismiss() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    window.setTimeout(() => this.element.remove(), 320)
  }
}
