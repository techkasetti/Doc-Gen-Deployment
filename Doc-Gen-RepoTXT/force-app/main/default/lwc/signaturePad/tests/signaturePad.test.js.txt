import { createElement } from 'lwc';
import SignaturePad from 'c/signaturePad';

describe('c-signature-pad', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('renders', () => {
    const element = createElement('c-signature-pad', { is: SignaturePad });
    document.body.appendChild(element);
    const card = element.shadowRoot.querySelector('lightning-card');
    expect(card).not.toBeNull();
  });
});
