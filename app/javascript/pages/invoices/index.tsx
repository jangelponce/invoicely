import { NuqsAdapter } from "nuqs/adapters/react";
import { Invoices } from "./components/invoices";

const InvoicesIndex = () => {
  return (
    <NuqsAdapter>
      <Invoices />
    </NuqsAdapter>
  );
};

export default InvoicesIndex;
