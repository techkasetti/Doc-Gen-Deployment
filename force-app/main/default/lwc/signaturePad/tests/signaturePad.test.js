// ...existing code...
import SignaturePad from 'c/signaturePad';

describe('c-signature-pad', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('renders', () => {
    const element = document.createElement('div');
    const lwcElement = createElement('c-signature-pad', { is: SignaturePad });
    document.body.appendChild(lwcElement);
    const card = lwcElement.shadowRoot.querySelector('lightning-card');
    expect(card).not.toBeNull();
  });
});