import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "overview", "details"]

  open() {
    this.showOverview()
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
    this.showOverview()
  }

  showDetails() {
    this.overviewTarget.hidden = true
    this.detailsTarget.hidden = false
  }

  showOverview() {
    this.detailsTarget.hidden = true
    this.overviewTarget.hidden = false
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
