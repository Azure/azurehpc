import React from 'react';
import ReactDOM from 'react-dom';
import AzurehpcApp from './AzurehpcApp';

it('renders without crashing', () => {
  const div = document.createElement('div');
  ReactDOM.render(<AzurehpcApp />, div);
  ReactDOM.unmountComponentAtNode(div);
});
