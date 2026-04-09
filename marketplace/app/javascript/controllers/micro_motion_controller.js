import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupRevealObserver()
    this.setupTiltInteractions()
  }

  disconnect() {
    if (this.revealObserver) this.revealObserver.disconnect()
    this.teardownTiltInteractions()
  }

  setupRevealObserver() {
    const revealElements = Array.from(document.querySelectorAll("[data-reveal]"))
    if (revealElements.length === 0) return

    this.revealObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          entry.target.classList.add("is-visible")
          this.revealObserver.unobserve(entry.target)
        })
      },
      { threshold: 0.15, rootMargin: "0px 0px -10% 0px" }
    )

    revealElements.forEach((element, index) => {
      element.classList.add("reveal-ready")
      const delay = element.dataset.revealDelay || `${Math.min(index * 40, 240)}`
      element.style.transitionDelay = `${delay}ms`
      this.revealObserver.observe(element)
    })
  }

  setupTiltInteractions() {
    this.tiltElements = Array.from(document.querySelectorAll("[data-tilt]"))
    this.tiltHandlers = []

    this.tiltElements.forEach((element) => {
      const onMove = (event) => {
        const rect = element.getBoundingClientRect()
        const px = (event.clientX - rect.left) / rect.width
        const py = (event.clientY - rect.top) / rect.height
        const rotateY = (px - 0.5) * 6
        const rotateX = (0.5 - py) * 6
        element.style.transform = `perspective(900px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-3px)`
      }

      const onLeave = () => {
        element.style.transform = "perspective(900px) rotateX(0deg) rotateY(0deg) translateY(0px)"
      }

      element.addEventListener("mousemove", onMove)
      element.addEventListener("mouseleave", onLeave)
      this.tiltHandlers.push({ element, onMove, onLeave })
    })
  }

  teardownTiltInteractions() {
    if (!this.tiltHandlers) return
    this.tiltHandlers.forEach(({ element, onMove, onLeave }) => {
      element.removeEventListener("mousemove", onMove)
      element.removeEventListener("mouseleave", onLeave)
    })
  }
}
