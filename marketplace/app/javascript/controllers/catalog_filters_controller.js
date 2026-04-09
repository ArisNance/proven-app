import { Controller } from "@hotwired/stimulus"

const SEARCH_DEBOUNCE_MS = 280

export default class extends Controller {
  connect() {
    this.submitTimer = null
  }

  disconnect() {
    this.clearPendingSubmit()
  }

  queueSubmit() {
    this.clearPendingSubmit()
    this.submitTimer = setTimeout(() => this.submit(), SEARCH_DEBOUNCE_MS)
  }

  submit() {
    this.clearPendingSubmit()
    if (this.element.requestSubmit) {
      this.element.requestSubmit()
      return
    }

    this.element.submit()
  }

  clearPendingSubmit() {
    if (!this.submitTimer) return

    clearTimeout(this.submitTimer)
    this.submitTimer = null
  }
}
