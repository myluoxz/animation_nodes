import random
from libc.string cimport memcpy
from libc.limits cimport INT_MAX
from .. random cimport uniformRandomInteger
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from ... data_structures cimport CList, PolygonIndicesList, ULongList

def shuffle(myList not None, seed):
    if isinstance(myList, list):
        return shuffle_PythonList(myList, seed)
    elif isinstance(myList, CList):
        return shuffle_CythonList(myList, seed)
    elif isinstance(myList, PolygonIndicesList):
        return shuffle_PolygonIndicesList(myList, seed)
    else:
        raise NotImplementedError()

def shuffle_PythonList(list myList, seed):
    random.seed(seed)
    random.shuffle(myList)
    return myList

def shuffle_CythonList(CList myList, seed):
    cdef:
        int _seed = (seed * 345722341) % INT_MAX
        char* data = <char*>myList.getPointer()
        Py_ssize_t length = myList.getLength()
        int elementSize = myList.getElementSize()
        void* tmp = PyMem_Malloc(elementSize)
        int i, offset

    if tmp == NULL:
        raise MemoryError()

    for i in range(length - 1, -1, -1):
        offset = uniformRandomInteger(_seed + i, 0, i) * elementSize

        memcpy(tmp, data + offset, elementSize)
        memcpy(data + offset, data + i * elementSize, elementSize)
        memcpy(data + i * elementSize, tmp, elementSize)

    PyMem_Free(tmp)
    return myList

def shuffle_PolygonIndicesList(PolygonIndicesList myList, seed):
    cdef:
        ULongList newOrder = ULongList(length = len(myList))
        Py_ssize_t i

    for i in range(len(myList)):
        newOrder.data[i] = i

    shuffle_CythonList(newOrder, seed)

    return myList.copyWithNewOrder(newOrder, checkIndices = False)
