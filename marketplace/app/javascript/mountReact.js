import React from "react"
import { createRoot } from "react-dom/client"
import ProductWizard from "./components/ProductWizard"

const mounts = document.querySelectorAll("[data-react-component='ProductWizard']")

mounts.forEach((node) => {
  const root = createRoot(node)
  root.render(<ProductWizard />)
})
