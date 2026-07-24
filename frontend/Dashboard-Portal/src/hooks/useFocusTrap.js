import { useEffect, useRef } from 'react';

/**
 * Custom hook to trap focus within an element (typically a modal dialog)
 * for keyboard accessibility (WCAG 2.1.2 No Focus-Trap / WAI-ARIA Dialog).
 *
 * @param {boolean} isOpen - Whether the focus trap should be active
 * @returns {React.RefObject} Ref to be attached to the modal container element
 */
export default function useFocusTrap(isOpen) {
  const containerRef = useRef(null);

  useEffect(() => {
    if (!isOpen) return;

    const containerElement = containerRef.current;
    if (!containerElement) return;

    // Focusable element selectors
    const focusableSelectors = [
      'a[href]',
      'area[href]',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      'button:not([disabled])',
      'iframe',
      'object',
      'embed',
      '[contenteditable]',
      '[tabindex]:not([tabindex^="-"])'
    ];

    const getFocusableElements = () => {
      return Array.from(containerElement.querySelectorAll(focusableSelectors.join(',')))
        .filter(el => {
          // Check if element is visually displayed and visible
          const style = window.getComputedStyle(el);
          return style.display !== 'none' && style.visibility !== 'hidden';
        });
    };

    // Save the element that had focus before opening the modal
    const previousActiveElement = document.activeElement;

    const focusableElements = getFocusableElements();
    if (focusableElements.length > 0) {
      // Focus the first focusable element
      focusableElements[0].focus();
    }

    const handleKeyDown = (e) => {
      if (e.key !== 'Tab') return;

      const currentFocusables = getFocusableElements();
      if (currentFocusables.length === 0) {
        e.preventDefault();
        return;
      }

      const firstElement = currentFocusables[0];
      const lastElement = currentFocusables[currentFocusables.length - 1];

      if (e.shiftKey) {
        // Shift + Tab: if on the first element, wrap around to the last
        if (document.activeElement === firstElement) {
          lastElement.focus();
          e.preventDefault();
        }
      } else {
        // Tab: if on the last element, wrap around to the first
        if (document.activeElement === lastElement) {
          firstElement.focus();
          e.preventDefault();
        }
      }
    };

    containerElement.addEventListener('keydown', handleKeyDown);

    return () => {
      containerElement.removeEventListener('keydown', handleKeyDown);
      // Restore focus to the element that triggered the modal
      if (previousActiveElement && typeof previousActiveElement.focus === 'function') {
        previousActiveElement.focus();
      }
    };
  }, [isOpen]);

  return containerRef;
}
