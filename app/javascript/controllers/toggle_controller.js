import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox" ]

  connect() {
    this.checkboxTarget.checked = this.data.get("value") == "true"
  }

  toggle(event) {
    event.preventDefault()

    fetch(this.data.get("url"), {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").getAttribute("content")
      },
      body: JSON.stringify({
        player: { public_ratings: this.checkboxTarget.checked }
      })
    })
    .then(response => {
      if (!response.ok) { throw response }
      return response.json()
    })
    .then(data => {
      if(data.status == "ok") {
        this.checkboxTarget.checked = !this.checkboxTarget.checked;
      }
    })
    .catch((error) => {
      console.error('Error:', error)
    })
  }
}
